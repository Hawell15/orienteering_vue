<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1>{{runner.runner_name}} {{runner.surname}}</h1>
        <p><strong>Anul Nașterii: </strong>{{runner.yob}}</p>
        <p><strong>Genul: </strong>{{runner.gender}}</p>
        <p><strong>Clubul: </strong><a :href="`/clubs/${runner.club_id}`">{{runner.club?.club_name}}</a></p>
        <p><strong>FOS ID: </strong>{{runner.id}}</p>
        <hr class="my-4">
        <div class="container">
            <div class="row">
                <div class="col-6">
                    <table>
                        <tr>
                            <td><strong>Titlul: </strong></td>
                            <td>
                                <a :href="`/categories/${runner.best_category_id}`">
                                    {{runner.best_category?.category_name}}
                                </a>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>Categoria actula: </strong></td>
                            <td>
                                <a :href="`/categories/${runner.category_id}`">
                                    {{runner.category?.category_name}}
                                </a>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>Valabila pina: </strong></td>
                            <td>
                                {{runner.category_valid}}
                            </td>
                        </tr>
                    </table>
                </div>
                <div class="col-6">
                    <table v-show="runner.wre_id">
                        <tr>
                            <td><strong>WRE ID: </strong></td>
                            <td> <a :href="`https://ranking.orienteering.org/PersonView?person=${runner.wre_id}`">
                                    {{runner.wre_id}}</a>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>Sprint WRE Ranking(Locul/Puncte): </strong></td>
                            <td>
                                {{runner.sprint_wre_place}}/{{runner.sprint_wre_rang}}
                            </td>
                        </tr>
                        <tr>
                            <td><strong>Padure WRE Ranking(Locul/Puncte): </strong></td>
                            <td>
                                {{runner.forest_wre_place}}/{{runner.forest_wre_rang}}
                            </td>
                        </tr>
                    </table>
                </div>
            </div>
        </div>
    </div>
    <br>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#membershipsTable" role="button" aria-expanded="false" aria-controls="membershipsTable">
            Afilieri
        </a>
    </p>
    <div class="collapse" id="membershipsTable">
        <div class="card card-body">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-primary">
                    <tr>
                        <th @click="orderMembershipTable('id')">ID</th>
                        <th @click="orderMembershipTable('club_name')">Club</th>
                        <th @click="orderMembershipTable('full_name')">Sportiv</th>
                        <th @click="orderMembershipTable('results_count')">Rezultate</th>
                        <th colspan="3">Acțiuni</th>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="element in memberships" :key="element.id">
                        <td><a :href="`/memberships/${element.id}`">{{element.id}}</a></td>
                        <td><a :href="`/clubs/${element.club_id}`">{{element.club_name}}</a></td>
                        <td><a :href="`/runners/${element.runner_id}`">{{element.full_name}}</a></td>
                        <td><a :href="`/results?membership_id=${element.id}`">{{element.results_count}}</a></td>
                        <td><a class="btn btn-sm btn-warning" :href="`/memberships/${element.id}`"> Arată </a></td>
                        <td><button class="btn btn-sm btn-success" @click="editElement(element)">Editează</button></td>
                        <td><button class="btn btn-sm btn-danger" @click="deleteElement(element)">Șterge</button></td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <br>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#confirmationsTable" role="button" aria-expanded="false" aria-controls="confirmationsTable">
            Istoria Îndeplinirilor
        </a>
    </p>
    <div class="collapse" id="confirmationsTable">
        <div class="card card-body">
            <table class="table table-striped table-bordered table-hover">
                <thead class="table-primary">
                    <tr>
                        <td>Data</td>
                        <td>Categoria Indeplinita</td>
                    </tr>
                </thead>
                <tbody>
                    <tr v-for="(element, index) in confirmationResults" :key="element.id" :class="{newConfirmation: element.result_category_name !== confirmationResults[index + 1]?.result_category_name}">
                        <td>{{element.date}}</td>
                        <td>{{element.result_category_name}}</td>
                    </tr>
                </tbody>
            </table>
        </div>
    </div>
    <br>
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
        <button class="btn btn-sm btn-success" @click="editElement(runner)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteRunner(runner.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <Modal ref="modal" :runner="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[ name="csrf-token"]').getAttribute('content')

const runner = ref({})
const runnerId = ref("")
const results = ref([])

const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

const confirmationResults = ref([])

const memberships = ref([])

const membershipSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

const modalElement = ref({})
const modal = ref(null)

onMounted(() => {
    runnerId.value = window.location.pathname.split('/').pop();
    getData();
    getConfirmationResults();
    getResults();
    getMemberships();
})

async function getData() {
    const res = await axios.get(`/runners/${runnerId.value}.json`)
    runner.value = res.data;
}

async function getResults() {
    resultSorting.value["runner"] = runnerId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

async function getMemberships() {
    membershipSorting.value["runner"] = runnerId.value
    const res = await axios.get('/memberships.json', { params: membershipSorting.value })
    memberships.value = res.data;
}

async function getConfirmationResults() {
    const params = {
        "sorting[sort_by]": "date",
        "sorting[direction]": "desc",
        "runner": runnerId.value,
        "status": ["confirmed"]
    }

    const res = await axios.get('/results.json', { params: params })
    confirmationResults.value = res.data;
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
    getResults();
}

function orderMembershipTable(sortKey) {
    orderTable(sortKey, membershipSorting)
    getResults();
}

function orderTable(sortKey, filters) {
    const isCurrentSort = filters.value["sorting[sort_by]"] === sortKey;
    const currentDir = filters.value["sorting[direction]"];

    filters.value["sorting[direction]"] = (isCurrentSort && currentDir === "asc") ? "desc" : "asc";
    filters.value["sorting[sort_by]"] = sortKey;
}

function editElement(runner) {
    modalElement.value = { ...runner }
    modal.value.show()
}

function updateElement(runnerData, done) {
    axios.patch(`/runners/${runnerData.id}.json`, { runner: runnerData }).then(res => {
        getData();
        done()
    })
}

function deleteRunner(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast sportiv?')) {
        axios.delete(`/runners/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/runners";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/runners";
    }
}
</script>
<style scoped>
.newConfirmation {
    background-color: #d4edda;
}
</style>
