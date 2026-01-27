<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> Afilierea {{membership.id}}</h1>
        <p><strong>Sportiv: </strong><a :href="`/runners/${membership.runner_id}`">{{membership.runner?.runner_name}} {{membership.runner?.surname}}</a></p>
        <p><strong>Club: </strong><a :href="`/clubs/${membership.club_id}`">{{membership.club?.club_name}}</a></p>
        <p><strong>Numarul de rezultate: </strong><a :href="`/results?membership=${membership.id}`">{{results.length}}</a></p>
    </div>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#resultsTable" role="button" aria-expanded="false" aria-controls="resultsTable">
            Rezultate
        </a>
    </p>
    <div class="collapse" id="resultsTable">
        <div class="card card-body">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-primary">
                    <tr>
                        <td @click="orderResultTable('place')">Locul</td>
                        <td @click="orderResultTable('full_name')">Sportiv</td>
                        <td @click="orderResultTable('club_name')">Club</td>
                        <td @click="orderResultTable('runner_category_name')">Categoria actuala</td>
                        <td @click="orderResultTable('time')">Timpul</td>
                        <td @click="orderResultTable('result_category_name')">Categoria Indeplinita</td>
                        <td @click="orderResultTable('status')">Indeplinire</td>
                        <td @click="orderResultTable('date')">Data</td>
                        <td @click="orderResultTable('competition_name')">Competitia</td>
                        <td @click="orderResultTable('group_name')">Grupa</td>
                        <td @click="orderResultTable('wre_points')">WRE Puncte</td>
                        <td @click="orderResultTable('ecn_points')">ECN Puncte</td>
                        <th colspan="3">Actiuni</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="element in results" :key="element.id">
                        <td>{{element.place}}</td>
                        <td><a :href="`/runners/${element.runner_id}`">{{element.full_name}}</a></td>
                        <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                        <td><a :href="`/categories/${element.runner_category_id}`">{{element.runner_category_name}}</a></td>
                        <td>{{formatResultTime(element.time)}}</td>
                        <td><a :href="`/categories/${element.result_category_id}`">{{element.result_category_name}}</a></td>
                        <td>{{element.status}}</td>
                        <td>{{element.date}}</td>
                        <td><a :href="`/competitions/${element.competition_id}`">{{element.competition_name}}</a></td>
                        <td><a :href="`/groups/${element.group_id}`">{{element.group_name}}</a></td>
                        <td>{{element.wre_points}}</td>
                        <td>{{element.ecn_points}}</td>
                        <td>
                            <a class="btn btn-sm btn-warning" :href="`/results/${element.id}`">
                                Arată
                            </a>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-success" @click="editElement(element)">
                                Editează
                            </button>
                        </td>
                        <td>
                            <button class="btn btn-sm btn-danger" @click="deleteElement(element.id)">
                                Șterge
                            </button>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editMembership(membership)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteMembership(membership.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <MembershipModal ref="modal" :membership="modalMembership" :isNew="false" @save="saveMembership" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import MembershipModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[ name="csrf-token"]').getAttribute('content')

const membership = ref({})
const membershipId = ref("")
const results = ref([])
const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const modalMembership = ref({})
const modal = ref(null)

onMounted(() => {
    membershipId.value = window.location.pathname.split('/').pop();
    getData();
    getResults();
})

async function getData() {
    const res = await axios.get(`/memberships/${membershipId.value}.json`)
    membership.value = res.data
}

async function getResults() {
    resultSorting.value["membership"] = membershipId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function formatResultTime(seconds) {
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = seconds % 60;

    return (
        String(h).padStart(2, '0') + ':' +
        String(m).padStart(2, '0') + ':' +
        String(s).padStart(2, '0')
    );
}

function editMembership(membership) {
    modalMembership.value = { ...membership }
    modal.value.show()
}

function saveMembership(membershipData, done) {
    axios.patch(`/memberships/${membershipData.id}.json`, { membership: membershipData }).then(res => {
        getData();
        done()
    })
}

function deleteMembership(id) {
    if (confirm('Esti sigur ca vrei sa stergi această afiliere?')) {
        axios.delete(`/memberships/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/memberships";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/memberships";
    }
}
</script>
