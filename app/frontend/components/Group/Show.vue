<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1>{{group.group_name}}</h1>
        <p><strong>Data: </strong>{{group.competition?.date}}</p>
        <p><strong>Competiția: </strong>{{group.competition?.competition_name}}</p>
        <hr class="my-4">
        <p><strong>Tipul Distanței: </strong>{{group.competition?.distance_type}}</p>
        <p v-if="group.competition?.ecn"><strong>Coeficient ECN: </strong>{{group.ecn_coeficient}}</p>
        <hr class="my-4">
        <table class="table table-striped table-bordered table-hover">
            <thead class="table-primary">
                <tr>
                    <td @click="orderResultTable('place')">Locul</td>
                    <td @click="orderResultTable('full_name')">Sportiv</td>
                    <td @click="orderResultTable('yob')">Anul Nașterii</td>
                    <td @click="orderResultTable('club_name')">Club</td>
                    <td @click="orderResultTable('runner_category_name')">Categoria actuala</td>
                    <td @click="orderResultTable('time')">Timpul</td>
                    <td @click="orderResultTable('result_category_name')">Categoria Indeplinita</td>
                    <td @click="orderResultTable('status')">Indeplinire</td>
                    <td v-if="group.competition?.wre_id" @click="orderResultTable('wre_points')">WRE Puncte</td>
                    <td v-if="group.competition?.ecn" @click="orderResultTable('ecn_points')">ECN Puncte</td>
                    <th colspan="3">Actiuni</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="element in results" :key="element.id">
                    <td>{{element.place}}</td>
                    <td><a :href="`/runners/${element.runner_id}`">{{element.full_name}}</a></td>
                    <td>{{element.yob}}</td>
                    <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                    <td><a :href="`/categories/${element.runner_category_id}`">{{element.runner_category_name}}</a></td>
                    <td>{{formatResultTime(element.time)}}</td>
                    <td><a :href="`/categories/${element.result_category_id}`">{{element.result_category_name}}</a></td>
                    <td :class="element.status">{{formatStatus(element.status)}}</td>
                    <td v-if="group.competition?.wre_id">{{element.wre_points}}</td>
                    <td v-if="group.competition?.ecn">{{element.ecn_points}}</td>
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
        <div class="half-width-table">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-warning">
                    <tr>
                        <th scope="col"> Categoria
                        </th>
                        <th> Procente
                        </th>
                        <th> Timpul
                        </th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>
                        </td>
                        <td>
                        </td>
                        <td>
                        </td>
                    </tr>
                </tbody>
            </table>
        </div>
        <div>Rang: {{group.rang }} </div>
        <div>Clasa: {{group.category_name}} </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editGroup(group)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteGroup(group.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <GroupModal ref="modal" :group="modalGroup" :isNew="false" @save="saveGroup" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import GroupModal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[ name="csrf-token"]').getAttribute('content')

const group = ref({})
const groupId = ref("")
const results = ref([])
const resultSorting = ref({
    "sorting[sort_by]": "place",
    "sorting[direction]": "asc"
})

const modalGroup = ref({})
const modal = ref(null)

onMounted(() => {
    groupId.value = window.location.pathname.split('/').pop();
    getData();
    getResults();
})

async function getData() {
    const res = await axios.get(`/groups/${groupId.value}.json`)
    group.value = res.data;
}

async function getResults() {
    resultSorting.value["group_data"] = groupId.value
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

function orderResultTable(sortKey) {
    orderTable(sortKey, resultSorting)
    getResults()
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function formatStatus(status) {
    const map = { confirmed: "Îndeplinit", pending: "În așteptare", unconfirmed: "Neconfirmat" }
    return map[status]
}

function editGroup(group) {
    modalGroup.value = { ...group }
    modal.value.show()
}

function saveGroup(groupData, done) {
    axios.patch(`/groups/${groupData.id}.json`, { group: groupData }).then(res => {
        getData();
        done()
    })
}

function deleteGroup(id) {
    if (confirm('Esti sigur ca vrei sa stergi această grupă?')) {
        axios.delete(`/groups/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/groups";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/groups";
    }
}
</script>
<style scoped>
.confirmed {
    background-color: #d4edda;
}

.pending {
    background-color: #ADD8E6;
}

.unconfirmed {
    background-color: #f8d7da;
}
</style>
