<template>
    <div class="mt-4 p-5 bg-light text-black rounded --bs-gray-500">
        <h1> {{club.club_name}}</h1>
        <p><strong>Alte Nume: </strong>{{club.alternative_club_name}}</p>
        <p><strong>Teritoriu: </strong>{{club.territory}}</p>
        <p><strong>Reprezentant: </strong>{{club.representative}}</p>
        <hr class="my-4">
        <p><strong>Email: </strong>{{club.email}}</p>
        <p><strong>Telefon: </strong>{{club.phone}}</p>
        <p><strong>Numarul de sportivi: </strong><a :href="`/runners?club=${club.id}`">{{runners.length}}</a></p>
        <p><strong>Numarul de rezultate: </strong><a :href="`/results?club=${club.id}`">{{results.length}}</a></p>
    </div>
    <p class="d-inline-flex gap-1">
        <a class="btn btn-primary" data-bs-toggle="collapse" href="#runnersTable" role="button" aria-expanded="false" aria-controls="runnersTable">
            Sportivi
        </a>
    </p>
    <div class="collapse" id="runnersTable">
        <div class="card card-body">
            <RunnersTable :elements="runners" @order="orderRunnerTable"></RunnersTable>
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
            <ResultsTable :elements="results" @order="orderResultTable"></ResultsTable>
        </div>
    </div>
    <p class="lead">
        <button class="btn btn-sm btn-success" @click="editElement(club)">Editeaza</button>
        <button class="btn btn-danger btn-sm" @click="deleteClub(club.id)">Sterge</button>
        <button class="btn btn-secondary btn-sm" @click="goBack()">Înapoi</button>
    </p>
    <Modal ref="modal" :club="modalElement" :isNew="false" @save="updateElement" />
</template>
<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal from './Modal.vue'
import RunnersTable from '../Runner/Table.vue'
import ResultsTable from '../Result/Table.vue'

axios.defaults.headers['X-CSRF-Token'] = document.querySelector('meta[  name="csrf-token"]').getAttribute('content')

const club = ref({})
const modalElement = ref({})
const modal = ref(null)
const runners = ref([])
const results = ref([])
const clubId = ref("")
const runnerSorting = ref({
    "sorting[sort_by]": "id",
    "sorting[direction]": "asc"
})

const resultSorting = ref({
    "sorting[sort_by]": "date",
    "sorting[direction]": "desc"
})

onMounted(() => {
    clubId.value = window.location.pathname.split('/').pop();
    getData();
    getRunners();
    getResults();
})

async function getData() {
    const res = await axios.get(`/clubs/${clubId.value}.json`)
    club.value = res.data;
}

async function getRunners() {
    runnerSorting.value["club"] = clubId.value
    const res = await axios.get('/runners.json', { params: runnerSorting.value })
    runners.value = res.data;
}

async function getResults() {
    resultSorting.value["club"] = clubId.value
    const res = await axios.get('/results.json', { params: resultSorting.value })
    results.value = res.data;
}

function orderRunnerTable(sortKey) {
    orderTable(sortKey, runnerSorting)
    getRunners()
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

function editElement(club) {
    modalElement.value = { ...club }
    modal.value.show()
}

function updateElement(clubData, done) {
    axios.patch(`/clubs/${clubData.id}.json`, { club: clubData }).then(res => {
        club.value = res.data
        done()
    })
}

function deleteClub(id) {
    if (confirm('Esti sigur ca vrei sa stergi aceast club?')) {
        axios.delete(`/clubs/${id}`).then(() => {
            if (document.referrer) {
                window.location = document.referrer;
            } else {
                window.location = "/clubs";
            }
        })
    }
}

function goBack() {
    if (document.referrer) {
        window.location = document.referrer;
    } else {
        window.location = "/clubs";
    }
}
</script>
